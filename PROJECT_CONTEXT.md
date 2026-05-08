# Project Context For Codex Local

## Project
- Repository: `/workspaces/vending-ad`
- Main solution: `VendingAdSolution/VendingAdSolution.sln`
- Main project: `VendingAdSolution/VendingAdSystem/VendingAdSystem.csproj`
- Framework: ASP.NET Core MVC/Web API on .NET 8
- Database: SQLite, keep SQLite for now
- Runtime URL: `http://localhost:5000`

## Communication Preference
- Use Vietnamese when talking to user.
- Be concise and practical.
- Avoid over-engineering.
- Make small, safe refactors.

## Main Goal
Refactor project into cleaner company-style foundation for future changes, without turning it into a large Clean Architecture/multi-project setup.

Target style: modular monolith inside single ASP.NET project.

## Architecture Direction
Keep one project, split folders by responsibility:

```text
VendingAdSystem/
├── Application/
│   ├── DTOs/
│   └── Services/
├── Domain/
│   └── Entities/
├── Infrastructure/
│   ├── Persistence/
│   ├── Repositories/
│   │   ├── Interfaces/
│   │   └── Implementations/
│   ├── Seed/
│   └── DependencyInjection.cs
├── Controllers/
├── Views/
├── wwwroot/
└── Program.cs
```

## Constraints
- Do not split into multiple projects yet.
- Do not add CQRS, MediatR, Unit of Work, AutoMapper, FluentValidation unless specifically needed.
- Do not switch to SQL Server yet.
- Keep SQLite.
- Do not reintroduce `Brand` concept.
- Admin manages users.
- Users login by username/email depending current form, but username uniqueness is required.
- Public self-registration was removed.

## Completed Refactor
- Moved entities into `Domain/Entities`:
  - `User`
  - `Admin`
  - `Device`
  - `Media`
  - `Campaign`
- Moved DTOs into `Application/DTOs/AuthDtos.cs`.
- Moved auth/session services into `Application/Services`:
  - `AuthService`
  - `CurrentSession`
- Added service layer:
  - `UserService`
  - `DeviceService`
  - `MediaService`
  - `CampaignService`
- Moved DbContext into `Infrastructure/Persistence/AppDbContext.cs`.
- Added generic repository:
  - `Infrastructure/Repositories/Interfaces/IRepository.cs`
  - `Infrastructure/Repositories/Implementations/Repository.cs`
- Added `Infrastructure/DependencyInjection.cs` to register:
  - `AppDbContext`
  - `IAuthService`
  - `ICurrentSession`
  - entity services
  - generic repository
- Added `Infrastructure/Seed/DatabaseSeeder.cs`.
- Cleaned `Program.cs` so it mainly wires services, middleware, routes, and calls seeder.
- Updated controllers to use services/repository instead of direct `_db` in controllers.
- Verified no direct `_db.` usage remains in controllers.
- Verified no `Brand`, `brand`, `BrandId`, `BrandName`, `/brand` remains in `*.cs` scan.
- `dotnet build VendingAdSolution/VendingAdSolution.sln` passed with `0 error`, `0 warning` after latest build.

## Current Important Files
- `VendingAdSolution/VendingAdSystem/Program.cs`
- `VendingAdSolution/VendingAdSystem/Domain/Entities/*.cs`
- `VendingAdSolution/VendingAdSystem/Application/DTOs/AuthDtos.cs`
- `VendingAdSolution/VendingAdSystem/Application/Services/*.cs`
- `VendingAdSolution/VendingAdSystem/Infrastructure/Persistence/AppDbContext.cs`
- `VendingAdSolution/VendingAdSystem/Infrastructure/DependencyInjection.cs`
- `VendingAdSolution/VendingAdSystem/Infrastructure/Seed/DatabaseSeeder.cs`
- `VendingAdSolution/VendingAdSystem/Infrastructure/Repositories/Interfaces/IRepository.cs`
- `VendingAdSolution/VendingAdSystem/Infrastructure/Repositories/Implementations/Repository.cs`
- `VendingAdSolution/VendingAdSystem/Controllers/AdminController.cs`
- `VendingAdSolution/VendingAdSystem/Controllers/PortalController.cs`
- `VendingAdSolution/VendingAdSystem/Controllers/AccountController.cs`

## Known Runtime Issue
When running `dotnet run`, logs show failed `ALTER TABLE` commands:

```text
ALTER TABLE Users ADD COLUMN Username TEXT NOT NULL DEFAULT ''
ALTER TABLE Devices ADD COLUMN UserId INTEGER NULL
ALTER TABLE Medias ADD COLUMN UserId INTEGER NULL
```

These are not fatal if caught, but they are noisy and should be cleaned.

Root cause: `DatabaseSeeder` tries to alter columns blindly. Columns already exist in current SQLite DB.

Recommended fix:
- Refactor `DatabaseSeeder` to check SQLite schema before running `ALTER TABLE`.
- Use `PRAGMA table_info(TableName)` to detect whether column exists.
- Only add column if missing.
- Keep backfill:
  - `UPDATE Users SET Username = Email WHERE Username = ''`
  - `UPDATE Devices SET UserId = {defaultUserId} WHERE UserId IS NULL`
  - `UPDATE Medias SET UserId = {defaultUserId} WHERE UserId IS NULL`

## Another Runtime Issue
`dotnet run` may fail with:

```text
Failed to bind to address http://127.0.0.1:5000: address already in use.
```

Root cause:
- Old app process already uses port `5000`.

Fix:
- Find process:

```bash
pgrep -af dotnet
```

- Kill only app process, not VS Code language server:

```bash
kill <PID>
```

- Or run on another port:

```bash
ASPNETCORE_URLS=http://localhost:5001 dotnet run --project VendingAdSolution/VendingAdSystem
```

## Current Auth Details
- Login page: `/Account/Login`
- Admin seed:
  - username/email: `admin@admin`
  - password: `admin@admin`
- Demo user may exist:
  - username/email can be `test@test` depending old DB state
  - password: `test@test`
- Admin user creation default password:
  - `TD@12345`

## Routes To Smoke Test
After build/run:
- `/Account/Login`
- `/`
- `/admin`
- `/admin/users`
- `/admin/devices`
- `/portal/dashboard`
- `/portal/devices`
- `/portal/videos`
- `/portal/playlist`
- `/api/playlist/{deviceCode}`
- `/api/heartbeat`
- `/api/portal/upload`

## Next Best Tasks
1. Clean `DatabaseSeeder` schema update logic so failed `ALTER TABLE` logs disappear.
2. Optionally decide whether to keep `Device.UserId` and `Media.UserId` nullable or enforce non-null later with a real migration.
3. Continue controller consolidation if desired:
   - consider merging `MediaController`, `PlaylistController`, `HeartbeatController` into clearer API grouping
   - do not overdo it if routes are currently useful
4. Add light smoke test script later if needed.
5. Keep build clean after every step:

```bash
dotnet build VendingAdSolution/VendingAdSolution.sln
```

## Important Notes For Codex
- User prefers pragmatic refactor, not over-engineering.
- Use smallest correct change.
- Preserve current behavior unless explicitly asked.
- Do not revert unrelated user changes.
- Do not commit unless user asks.
- Use Vietnamese for communication.
