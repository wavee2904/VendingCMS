using VendingAdWorker;
using VendingAdSystem.Infrastructure;

var builder = Host.CreateApplicationBuilder(args);
builder.Services.Configure<RabbitMqWorkerOptions>(builder.Configuration.GetSection("RabbitMQ"));
builder.Services.AddWorkerInfrastructure(builder.Configuration);
builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();
