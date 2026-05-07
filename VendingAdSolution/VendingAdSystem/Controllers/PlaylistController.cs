using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VendingAdSystem.Data;

namespace VendingAdSystem.Controllers;

[ApiController]
[Route("api")]
public class PlaylistController : ControllerBase
{
    private readonly AppDbContext _db;

    public PlaylistController(AppDbContext db) => _db = db;

    /// <summary>
    /// GET /api/playlist/{deviceCode}
    /// Returns the assigned video URL for a tablet.
    /// </summary>
    [HttpGet("playlist/{deviceCode}")]
    public async Task<IActionResult> GetPlaylist(string deviceCode)
    {
        var items = await _db.Campaigns
            .Include(c => c.Device)
            .Include(c => c.Media)
            .Where(c => c.Device.DeviceCode == deviceCode)
            .Select(c => new
            {
                c.Media.FileUrl,
                c.Media.FileName
            })
            .ToListAsync();

        if (!items.Any())
            return NotFound(new { message = $"No campaign assigned to device '{deviceCode}'." });

        return Ok(items);
    }
}
