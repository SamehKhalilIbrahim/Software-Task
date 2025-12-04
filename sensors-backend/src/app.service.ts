import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHello(): string {
    return 'Where your endpoint bro, try /reading/latest ';
  }
}
