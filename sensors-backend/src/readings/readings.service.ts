import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateReadingDto } from './dto/create-reading.dto';
import { Reading } from './entities/reading.entity';

@Injectable()
export class ReadingsService {
  constructor(
    // Inject the TypeORM Repository for the Reading entity
    @InjectRepository(Reading)
    private readingsRepository: Repository<Reading>,
  ) {}

  // 1. Save a new reading (POST /readings)
  async create(createReadingDto: CreateReadingDto): Promise<Reading> {
    const newReading = this.readingsRepository.create(createReadingDto);
    return this.readingsRepository.save(newReading);
  }

  // 2. Get the latest reading (GET /readings/latest)
  async findLatest(): Promise<Reading> {
    // ⬇️ CHANGE: Use find() with take: 1 to get the top row of the sorted results
    const latestReading = await this.readingsRepository.find({
      order: { createdAt: 'DESC' },
      take: 1, // Only retrieve the first result (the latest one)
    });

    if (latestReading.length === 0) {
      // Check if the array is empty
      // Throw an error if no readings exist
      throw new NotFoundException('No sensor readings found.');
    }

    // Return the single item from the array
    return latestReading[0];
  }
}
