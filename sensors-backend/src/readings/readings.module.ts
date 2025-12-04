import { Module } from '@nestjs/common';
import { ReadingsService } from './readings.service';
import { ReadingsController } from './readings.controller';
import { TypeOrmModule } from '@nestjs/typeorm'; // <-- 1. Import TypeOrmModule
import { Reading } from './entities/reading.entity'; // <-- 2. Import the Entity

@Module({
  imports: [
    // 3. Register the entity for this feature/module
    TypeOrmModule.forFeature([Reading]),
  ],
  controllers: [ReadingsController],
  providers: [ReadingsService],
})
export class ReadingsModule {}
