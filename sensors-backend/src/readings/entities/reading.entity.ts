import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('sensor_readings')
export class Reading {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'float' })
  lightValue: number; // <-- New field for Light Sensor Reading

  @Column({ type: 'float' })
  smokeValue: number; // <-- New field for Smoke Sensor Reading

  // Change: Remove the explicit { type: 'timestamp' }
  // TypeORM will automatically use a compatible SQLite data type (usually TEXT)
  // and handle the Date object conversion for you.
  @CreateDateColumn({ name: 'created_at' }) // <-- NO specific type argument needed here
  createdAt: Date;
}
