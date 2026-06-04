import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { IUserRepository } from '../domain/user.repository.interface';
import { UserEntity } from '../domain/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @Inject('IUserRepository')
    private readonly userRepository: IUserRepository,
  ) {}

  async findById(id: string): Promise<UserEntity> {
    const user = await this.userRepository.findById(id);
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  async findByEmail(email: string): Promise<UserEntity | null> {
    return this.userRepository.findByEmail(email);
  }

  async create(user: Partial<UserEntity>): Promise<UserEntity> {
    return this.userRepository.create(user);
  }

  async update(id: string, userDto: Partial<UserEntity>): Promise<UserEntity> {
    // Check if exists
    await this.findById(id);
    return this.userRepository.update(id, userDto);
  }

  async remove(id: string): Promise<boolean> {
    await this.findById(id);
    return this.userRepository.delete(id);
  }

  async findAll(): Promise<UserEntity[]> {
    return this.userRepository.findAll();
  }
}
