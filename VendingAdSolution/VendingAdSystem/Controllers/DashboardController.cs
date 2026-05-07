using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VendingAdSystem.Data;

namespace VendingAdSystem.Controllers;

public class DashboardController : Controller
{
    private readonly AppDbContext _db;

    public DashboardController(AppDbContext db) => _db = db;

    [HttpGet("/")]
    [HttpGet("/dashboard")]
    public async Task<IActionResult> Index()
    {
        var devices = await _db.Devices
            .Include(d => d.Campaigns)
            .ThenInclude(c => c.Media)
            .OrderByDescending(d => d.LastSeen)
            .ToListAsync();

        return View(devices);
    }

    [HttpGet("/upload")]
    public IActionResult Upload() => View();
}
