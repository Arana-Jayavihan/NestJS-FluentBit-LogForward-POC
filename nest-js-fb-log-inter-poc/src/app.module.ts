
import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';
import { AppController } from './app.controller';
import { AppService } from './app.service';

const transport = {
  targets: [
    {
      target: 'pino-socket',
      options: {
        mode: 'tcp',
        address: '127.0.0.1',
        port: 9000,
      },
    },
    {
      target: 'pino-pretty',
      level: 'debug',
      options: {
        colorize: true,
        singleLine: true,
        translateTime: 'SYS:standard'
      },
    }
  ]
}

@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        transport: transport,
        level: 'info',
        serializers: {
          req: (req) => ({
            id: req.id,
            method: req.method,
            url: req.url,
          }),
          res: (res) => ({
            statusCode: res.statusCode,
          }),
        },
      },
    })
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }