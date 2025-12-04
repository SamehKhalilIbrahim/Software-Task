// import { IsNotEmpty, IsNumber } from 'class-validator';
// import { Type } from 'class-transformer';

export class CreateReadingDto {
  lightValue: number;

  smokeValue: number; // Expects a number for smoke
}
