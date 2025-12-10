
import { Module } from '@nestjs/common';
import { LoggerModule } from 'nestjs-pino';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { destination } from 'pino';

@Module({
  imports: [
    LoggerModule.forRoot({
      pinoHttp: {
        transport: {
          pipeline: [
            {
              target: 'pino-syslog',
              options: {
                facility: 23, // local7
                appname: 'local7'
              }
            },
            {
              target: 'pino-socket',
              options: {
                mode: 'tcp',
                address: '165.22.52.204',
                port: 9000
              }
            }
          ],
          targets: [
            // Pretty console output for development
            {
              target: 'pino-pretty',
              level: 'debug',
              options: {
                colorize: true,
                singleLine: true,
                translateTime: 'SYS:standard',
              },
            }
          ],
        },
        level: process.env.NODE_ENV !== 'production' ? 'debug' : 'info',
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
export class AppModule {}