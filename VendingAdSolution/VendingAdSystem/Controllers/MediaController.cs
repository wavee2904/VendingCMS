using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VendingAdSystem.Data;
using VendingAdSystem.Models;

namespace VendingAdSystem.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MediaController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IWebHostEnvironment _env;

    public MediaController(AppDbContext db, IWebHostEnvironment env)
    {
        _db = db;
        _env = env;
    }

    /// <summary>
    /// POST /api/media/upload
    /// Form fields: file (video), deviceCode (string)
    /// Saves video to wwwroot/uploads, creates Media + Campaign records.
    /// Replaces any existing campaign for that device.
    /// </summary>
    [HttpPost("upload")]
    [RequestSizeLimit(500_000_000)] // 500 MB max
    public async Task<IActionResult> Upload(IFormFile file, [FromForm] string deviceCode)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { message = "No file provided." });

        if (string.IsNullOrWhiteSpace(deviceCode))
            return BadRequest(new { message = "Device code is required." });

        // Ensure device exists
        var device = await _db.Devices.FirstOrDefaultAsync(d => d.DeviceCode == deviceCode);
        if (device == null)
        {
            device = new Device { DeviceCode = deviceCode };
            _db.Devices.Add(device);
            await _db.SaveChangesAsync();
        }

        // Save file to wwwroot/uploads
        var uploadsPath = Path.Combine(_env.WebRootPath, "uploads");
        Directory.CreateDirectory(uploadsPath);

        var uniqueName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var filePath   = Path.Combine(uploadsPath, uniqueName);

        using (var stream = new FileStream(filePath, FileMode.Create))
            await file.CopyToAsync(stream);

        var baseUrl = $"{Request.Scheme}://{Request.Host}";
        var media = new Media
        {
            FileName = file.FileName,
            FileUrl  = $"{baseUrl}/uploads/{uniqueName}"
        };
        _db.Medias.Add(media);
        await _db.SaveChangesAsync();

        // Replace existing campaign assignment for this device
        var existing = _db.Campaigns.Where(c => c.DeviceId == device.Id);
        _db.Campaigns.RemoveRange(existing);
        _db.Campaigns.Add(new Campaign { DeviceId = device.Id, MediaId = media.Id });
        await _db.SaveChangesAsync();

        return Ok(new { media.FileUrl, media.FileName, deviceCode });
    }
}
