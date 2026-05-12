# Project Context

## Project
- Repository: `/workspaces/vending-ad`
- GitHub repo: `https://github.com/huyle2904/vending-ad-web`
- Current branch for coding: `dev`
- Default PR target branch: `main`
- Main solution: `VendingAdSolution/VendingAdSolution.sln`
- Main project: `VendingAdSolution/VendingAdSystem/VendingAdSystem.csproj`
- Framework: ASP.NET Core MVC/Web API on .NET 8
- Database: EF Core multi-provider. Local default is SQLite; Render uses PostgreSQL; future local MSSQL is supported by config.
- App is now web-only. Old mobile folder `VendingAdFlutter` was removed from tracked repo.

## Communication
- Talk to user in Vietnamese.
- Be concise, practical, direct.
- Prefer small safe changes.

## Current Product Direction
- `Media` = personal video library.
- `Playlist` = reusable template only.
- `PlaybackSchedule` = real playback plan.
- Device playback reads from active schedules.

## UI Direction
- Keep CMS UI simple, direct, and consistent.
- Use one shared visual language across portal and admin.
- Prefer white/light surfaces, one primary blue, minimal decoration.
- Avoid colorful gradients, emoji icons, and marketing-style visuals.
- App UI text is now standardized to Vietnamese.
- Keep internal code identifiers in English, but all visible user-facing text should stay Vietnamese.

## Business Flow
- User uploads video into personal library.
- User creates playlist template from library videos.
- User creates schedule from either:
  - selected single videos
  - or one playlist template
- User chooses one or more owned devices.
- Same schedule time window applies to all selected devices.
- Different time windows require separate schedules.
- No cross-midnight playback.

## Time Rules
- User input is Vietnam time.
- UI output is Vietnam time.
- `DateTime` persisted in UTC.
- `StartTime` / `EndTime` stored as `TimeSpan` in Vietnam local day time.
- Do not use `DateTime.Now` for persistence or business checks.

## Core Models
- Keep:
  - `User`
  - `Admin`
  - `Device`
  - `Media`
  - `Playlist`
  - `PlaylistItem`
- Active schedule model:
  - `PlaybackSchedule`
  - `PlaybackScheduleDevice`
  - `PlaybackScheduleItem`

## Important Meaning
### Media
- Upload creates only `Media`.
- No device/time attached.

### Playlist
- Optional reusable template.
- Ordered list of user videos.
- No device/time attached.

### PlaybackSchedule
- Real playback plan.
- Has devices, date range, time range, ordered media snapshot.
- Playback API reads from this model.

## Current Architecture
- `Controllers/*`
  - MVC pages + API endpoints
- `Application/Services/*`
  - business logic
- `Application/DTOs/*`
  - request/response objects
- `Infrastructure/Persistence/AppDbContext.cs`
  - EF Core context
- `Infrastructure/Seed/DatabaseSeeder.cs`
  - SQLite schema repair + provider-safe seed data
- `Infrastructure/Repositories/*`
  - generic repository

## Key Files
- `VendingAdSolution/VendingAdSystem/Controllers/PortalController.cs`
- `VendingAdSolution/VendingAdSystem/Controllers/PortalApiController.cs`
- `VendingAdSolution/VendingAdSystem/Controllers/AdminController.cs`
- `VendingAdSolution/VendingAdSystem/Application/Services/PlaybackScheduleService.cs`
- `VendingAdSolution/VendingAdSystem/Application/Services/PlaylistManagementService.cs`
- `VendingAdSolution/VendingAdSystem/Application/Services/PlaylistService.cs`
- `VendingAdSolution/VendingAdSystem/Infrastructure/Seed/DatabaseSeeder.cs`
- `VendingAdSolution/VendingAdSystem/Views/Portal/Videos.cshtml`
- `VendingAdSolution/VendingAdSystem/Views/Portal/Playlist.cshtml`
- `VendingAdSolution/VendingAdSystem/Views/Portal/Schedules.cshtml`
- `VendingAdSolution/VendingAdSystem/Views/PortalDevices/Index.cshtml`
- `VendingAdSolution/VendingAdSystem/wwwroot/css/site.css`

## Auth Details
- Admin seed:
  - `admin@admin` / `admin@admin`
- Demo user:
  - `test@test` / `test@test`
- Admin-created user default password:
  - `TD@12345`

## What Is Done
- Removed legacy `Campaign` and `PlaylistDevice` flow from active logic.
- Converted playlist to template-only model.
- Added playback schedule domain + services + UI.
- Kept playback API URL pattern `/api/portal/playlist/{deviceCode}`.
- Added admin schedule list/filter/toggle/delete page.
- Added DB seeder repair for old `Playlists` schema and `PlaybackSchedules` columns.
- Split repository to web-only.
- Added GitHub Actions CI workflow for PR to `main` and pushes to `dev`/`main`.
- Added Device Wall web simulator for multiple devices.
- Added live schedule item editing and drag-drop reorder in schedule detail modal.
- Upgraded portal dashboard with correct current/upcoming schedule logic.
- Upgraded login UI and standardized global CMS styling.
- Installed `ui-ux-pro-max` skill for OpenCode in `.opencode/skills/ui-ux-pro-max/`.
- Added quick-play flow on portal `Devices` and `Dashboard` cards using existing immediate schedule flow.
- Added schedule status tag `Đã lên lịch` and distinct color for scheduled items.
- Synchronized major portal/admin UI text to Vietnamese.
- Installed `find-skills`, `frontend-design`, and `web-design-guidelines` skills for OpenCode.
- Added Render Docker deploy config with Render PostgreSQL support.
- Added DB provider switch via `DatabaseProvider` (`Sqlite`, `Postgres`, `SqlServer`).

## Database Provider / Deploy Notes
- Current Render target uses PostgreSQL from `render.yaml`:
  - `DatabaseProvider=Postgres`
  - `ConnectionStrings__DefaultConnection` comes from Render database `vending-ad-db`
- Local default remains SQLite in `appsettings.json`:
  - `DatabaseProvider=Sqlite`
  - `DefaultConnection=Data Source=vendingad.db`
- To switch later to local MSSQL, change config/env only:
  - `DatabaseProvider=SqlServer`
  - `ConnectionStrings__DefaultConnection=Server=localhost;Database=VendingAdDb;Trusted_Connection=True;TrustServerCertificate=True;`
- No data migration from Render PostgreSQL to MSSQL is required unless user explicitly asks; user said data does not need to be kept.
- `Infrastructure/DependencyInjection.cs` chooses EF provider by `DatabaseProvider`.
- `DatabaseSeeder.Seed` runs SQLite repair only for SQLite; PostgreSQL/MSSQL use `EnsureCreated()` plus EF seed data.
- Avoid adding provider-specific raw SQL unless guarded by provider checks (`db.Database.IsSqlite()`, etc.).
- Uploads on Render still use `/data/uploads`; without persistent disk, uploaded video files may be temporary even though DB is online.

## Current In-Progress Work
- CMS-wide Vietnamese localization and UI polish completed for current scope.
- Next likely work:
  - final visual QA on mobile and desktop
  - any small text cleanup spotted during manual review
  - commit stable batch to `dev`

## Next Likely Work
1. Do final manual QA on dashboard, devices, schedules, playlist, videos, admin, profile, settings.
2. Clean any remaining English visible text if found.
3. Commit stable batch to `dev` when ready.
4. Create PR from `dev` to `main` when ready.

## Known Notes
- Repo is web-only now. Do not reintroduce old `VendADS` or Flutter code unless user explicitly asks.
- `opencode.json` is intentionally tracked because user wants it available on personal machine.
- `wwwroot/uploads/` is runtime data and ignored.
- Use another port if `5000`/`5001` already in use.
- `ui-ux-pro-max` skill installed under `.opencode/skills/ui-ux-pro-max/`.
- `frontend-design` and `web-design-guidelines` are installed under `.agents/skills/`.
- `find-skills` is installed under `.agents/skills/`.

## Commands
```bash
dotnet build VendingAdSolution/VendingAdSolution.sln
ASPNETCORE_URLS=http://localhost:5001 dotnet run --no-launch-profile --project VendingAdSolution/VendingAdSystem
```

## Important Constraints
- No per-device time inside same schedule.
- Same schedule time applies to all selected devices.
- No cross-midnight time range.
- Keep changes small and reversible.
- Prefer continuing existing service/repository style.
