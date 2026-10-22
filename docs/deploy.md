# Deploying Hassan Traders

The app ships as one Docker image (see `Dockerfile`), deployed with Kamal to a single server: an AWS EC2 instance (Ubuntu, x86_64) at `15.252.88.73`. It serves `https://hassantrader.com` and `https://www.hassantrader.com`. The image goes to `ghcr.io/devsaimsohail/hassan_traders`.

- **App container**: Thruster in front of a single Puma process on port 80. Background jobs run on Rails' async adapter, a thread pool inside Puma; see "Background jobs" below. There is no separate job container.
- **kamal-proxy**: terminates SSL with a Let's Encrypt certificate for the domain and routes to the app. The app has `assume_ssl` and `force_ssl` on.
- **Postgres 17 accessory** (`hassan_traders-db`): holds four databases: `hassan_traders_production`, plus `_cache`, `_queue` and `_cable` for Solid Cache, Queue and Cable. `_queue` sits empty until Solid Queue is switched on. Data lives in `~/hassan_traders-db/data` on the server.
- **Storage volume** (`hassan_traders_storage`): Active Storage files (company logos), mounted at `/rails/storage`.

Every boot of the app container runs `bin/rails db:prepare` (from `bin/docker-entrypoint`). On a new server that creates the databases and loads `db/structure.sql` and the Solid schemas. After that it runs any pending migrations.

## Before the first deploy

1. **EC2 security group**: allow inbound TCP 80 and 443 from anywhere (`0.0.0.0/0` and `::/0`). Let's Encrypt and visitors need both. Keep 22 open, ideally only from your own IP.
2. **Elastic IP**: make sure `15.252.88.73` is an Elastic IP attached to the instance. A plain public IP changes when the instance is stopped and started, and then DNS and `config/deploy.yml` would both be wrong.
3. **DNS at GoDaddy**: for `hassantrader.com`, set the `@` A record to `15.252.88.73`. Remove any domain forwarding or parked-page records; GoDaddy's parking IPs are `3.33.130.190` and `15.197.148.33`. `www` is already a CNAME to `@`. Check with `dig +short hassantrader.com` before `setup`. kamal-proxy can only get the SSL certificate once both names resolve to the server.
4. **Server, once**: Kamal logs in as `ubuntu` with `~/.ssh/hassan_tarders.pem` (set under `ssh:` in `config/deploy.yml`). It can't install Docker without root, so install Docker by hand. Add 2 GB of swap too: the t3.micro has under 1 GB of RAM (see "Memory on the t3.micro").

   ```bash
   ssh -i ~/.ssh/hassan_tarders.pem ubuntu@15.252.88.73
   ```

   Then on the server:

   ```bash
   sudo apt-get update && sudo apt-get install -y docker.io
   sudo usermod -aG docker ubuntu
   sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
   echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

   Log out and back in so the docker group applies, then check that `docker ps` works without sudo.
5. **Registry token**: on GitHub go to Settings → Developer settings → Personal access tokens → Tokens (classic). Create a token with `write:packages` just for deploys.
6. **Secrets**: `.kamal/secrets` reads these from your shell. Never write the values into the file.

   | Secret | Where it comes from |
   | --- | --- |
   | `KAMAL_REGISTRY_PASSWORD` | the GitHub token from step 5 |
   | `HASSAN_TRADERS_DATABASE_PASSWORD` | a new long random password: `openssl rand -hex 24`. Keep it in a password manager. |
   | `RAILS_MASTER_KEY` | read from `config/master.key`. Get it from the other partner if it isn't on your machine. It isn't in git. |

   ```bash
   export KAMAL_REGISTRY_PASSWORD=...
   export HASSAN_TRADERS_DATABASE_PASSWORD=...
   ```

   Postgres only reads its password the first time it creates its data directory. Changing `HASSAN_TRADERS_DATABASE_PASSWORD` later does not change the existing database user.

## First deploy

```bash
bin/kamal server bootstrap
bin/kamal accessory boot db
bin/kamal setup
```

Start Postgres first so it finishes initialising before the app's first `db:prepare`. `setup` skips the accessory because it is already running. It then builds and pushes the image, starts kamal-proxy and boots the app.

kamal-proxy requests the Let's Encrypt certificates on the first HTTPS request to each name. Open `https://hassantrader.com/up` and `https://www.hassantrader.com/up` once after `setup`. If the certificate fails, check DNS and the security group first, then `bin/kamal proxy logs`.

Building an amd64 image on an Apple Silicon Mac goes through emulation and is slow, about 10–20 minutes the first time. For faster builds, set `builder.remote` in `config/deploy.yml`.

### First company and partner

`db/seeds.rb` is development demo data with a shared password, so production skips it. Even when `db:prepare` seeds a new database, it does nothing there. Instead, create the real company and the first partner from the console:

```bash
bin/kamal console
```

```ruby
company = Company.create!(name: "Hassan Traders")
partner = User.create!(name: "Muhammad Hassan", mobile: "03001234567", password: "a long password")
partner.assign_role!(:partner, company)
```

Creating the company also creates its default role permissions and units. The partner can now log in and add everyone else from Settings.

## Everyday commands

| Task | Command |
| --- | --- |
| Deploy the current commit | `bin/kamal deploy` |
| Rails console | `bin/kamal console` |
| Shell in the app container | `bin/kamal shell` |
| Tail logs | `bin/kamal logs` |
| psql on the production database | `bin/kamal dbc` |
| Run migrations by hand | `bin/kamal app exec "bin/rails db:migrate"` |
| List deployed versions / roll back | `bin/kamal app containers`, `bin/kamal rollback <version>` |

Migrations run on every deploy, because each new container runs `db:prepare` before it starts serving.

## Memory on the t3.micro

The instance has 908 MB of RAM. Ubuntu and Docker already use about 370 MB, which leaves about 540 MB for:

| Part | Under load | Limit |
| --- | --- | --- |
| App container (Puma + Thruster) | ~215 MB | 512 MB (`servers.web.options.memory`) |
| Postgres | ~70 MB | 256 MB (`accessories.db.options.memory`) |
| kamal-proxy | ~20 MB | none |

These numbers come from running the production image locally with the demo data, through every page and PDF, with three users at a time. The settings that keep them this low:

- **Jobs in Puma**: Active Job uses the async adapter with 2 threads, not Solid Queue. Solid Queue would add 4 processes, about 240 MB.
- **jemalloc**: `MALLOC_CONF` in the `Dockerfile` hands freed memory back to the OS sooner. That saves about 30 MB.
- **YJIT capped at 32 MB** (`config.yjit` in `production.rb`). It stays on for faster PDFs and lower CPU, but can't grow to its default of about 128 MB.
- **Postgres settings** (`accessories.db.cmd`): 64 MB shared buffers, 30 connections and JIT off.
- **One Puma process.** Don't set `WEB_CONCURRENCY` on this server.

Keep the 2 GB swap file from step 4 as a safety net. If memory gets tight later, these services do nothing useful on this server and can be switched off. Together they free about 50 MB:

```bash
sudo systemctl mask --now fwupd
sudo snap remove amazon-ssm-agent
```

Only remove the SSM agent if you don't use AWS Session Manager. Check usage any time with `free -m` and `docker stats --no-stream` on the server.

## Background jobs

The app has no jobs of its own. The only ones are Active Storage's for company logos: analysing an upload and deleting a removed logo. They run on Rails' async adapter, a thread pool inside Puma. A job queued at the moment the app restarts, for example during a deploy, is lost; for these jobs that only means missing logo metadata or a leftover file.

Jobs queued from `bin/kamal console` run while the console stays open. One-off `bin/rails runner` scripts exit before their jobs run.

When the app needs durable jobs (reminders, scheduled reports, emails), switch to Solid Queue. It's already installed, and its database exists:

1. In `config/environments/production.rb`, set `config.active_job.queue_adapter = :solid_queue`.
2. In `config/deploy.yml`, uncomment `SOLID_QUEUE_IN_PUMA: true`.
3. To keep memory low, also add `solid_queue_mode :async` next to `plugin :solid_queue` in `config/puma.rb`. That runs it as threads instead of 4 forked processes. Raise the queue database's `max_connections` in `config/database.yml` to about 10.

## Backups

Nothing is backed up automatically yet. Both the database and the uploaded files live only on the server. Until there is a scheduled backup, take copies by hand over SSH and keep them off the server:

```bash
ssh -i ~/.ssh/hassan_tarders.pem ubuntu@15.252.88.73 'docker exec hassan_traders-db pg_dump -U hassan_traders -Fc hassan_traders_production' > hassan_traders.dump
ssh -i ~/.ssh/hassan_tarders.pem ubuntu@15.252.88.73 'sudo tar czf - -C /var/lib/docker/volumes/hassan_traders_storage/_data .' > hassan_traders_storage.tgz
```

## CI

`.github/workflows/ci.yml` runs on every push to `main` and on every pull request:

- `scan_ruby`: Brakeman and bundler-audit. Reviewed false positives are listed with notes in `config/brakeman.ignore`.
- `scan_js`: `bin/importmap audit`.
- `lint`: RuboCop.
- `test`: `bin/rails test` against Postgres 17. This also builds the Tailwind CSS first.

CI does not deploy. Deploys are run by hand with `bin/kamal deploy`.
