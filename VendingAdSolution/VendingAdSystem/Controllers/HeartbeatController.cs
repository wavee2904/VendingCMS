using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VendingAdSystem.Data;
using VendingAdSystem.Models;

namespace VendingAdSystem.Controllers;

[ApiController]
[Route("api")]
public class HeartbeatController : ControllerBase
{
    private readonly AppDbContext _db;

    public HeartbeatController(AppDbContext db) => _db = db;

    /// <summary>
    /// POST /api/heartbeat
    /// Body: { "deviceCode": "TABLET-001" }
    /// Updates LastSeen for the device. Auto-registers unknown devices.
    /// </summary>
    [HttpPost("heartbeat")]
    public async Task<IActionResult> Heartbeat([FromBody] HeartbeatRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.DeviceCode))
            return BadRequest(new { message = "DeviceCode is required." });

        var device = await _db.Devices
            .FirstOrDefaultAsync(d => d.DeviceCode == req.DeviceCode);

        if (device == null)
        {
            device = new Device { DeviceCode = req.DeviceCode };
            _db.Devices.Add(device);
        }

        device.LastSeen = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(new { message = "ok", timestamp = device.LastSeen });
    }
}

public record HeartbeatRequest(string DeviceCode);
