using DotNetEnv;
using EasyNetQ;
using Lexor.Services.Database;
using Lexor.Subscriber;
using Microsoft.EntityFrameworkCore;

Env.TraversePath().Load();

var builder=Host.CreateApplicationBuilder();

builder.Services.AddDbContext<LexorDbContext>(options => options.UseSqlServer(builder.Configuration["ConnectionStrings:DefaultConnection"]));

builder.Services.AddSingleton<IBus>(_ =>
    RabbitHutch.CreateBus(builder.Configuration["RabbitMQ:ConnectionString"]));

builder.Services.AddHostedService<LeaveNotificationConsumer>();
builder.Services.AddHostedService<LeaveCompletionWorker>();

var host = builder.Build();
host.Run(); 