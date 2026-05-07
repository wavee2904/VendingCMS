namespace VendingAdSystem.Models;

public class Device
{
    public int Id { get; set; }
    public string DeviceCode { get; set; } = string.Empty;
    public DateTime? LastSeen { get; set; }

    public ICollection<Campaign> Campaigns { get; set; } = new List<Campaign>();
}

public class Media
{
    public int Id { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string FileUrl { get; set; } = string.Empty;

    public ICollection<Campaign> Campaigns { get; set; } = new List<Campaign>();
}

public class Campaign
{
    public int Id { get; set; }

    public int DeviceId { get; set; }
    public Device Device { get; set; } = null!;

    public int MediaId { get; set; }
    public Media Media { get; set; } = null!;
}
