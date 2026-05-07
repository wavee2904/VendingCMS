using Microsoft.EntityFrameworkCore;
using VendingAdSystem.Models;

namespace VendingAdSystem.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Device> Devices => Set<Device>();
    public DbSet<Media> Medias => Set<Media>();
    public DbSet<Campaign> Campaigns => Set<Campaign>();
}
