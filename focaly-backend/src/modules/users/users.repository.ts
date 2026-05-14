import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { FilterQuery, Model, UpdateQuery } from 'mongoose';

import { User, UserDocument } from './schemas/user.schema';

export interface CreateUserInput {
  email: string;
  passwordHash: string | null;
  name: string;
  googleId?: string | null;
  avatarUrl?: string | null;
  emailVerified?: boolean;
}

@Injectable()
export class UsersRepository {
  constructor(@InjectModel(User.name) private readonly userModel: Model<UserDocument>) {}

  create(input: CreateUserInput): Promise<UserDocument> {
    return new this.userModel({
      email: input.email.toLowerCase(),
      passwordHash: input.passwordHash,
      name: input.name,
      googleId: input.googleId ?? null,
      avatarUrl: input.avatarUrl ?? null,
      emailVerified: input.emailVerified ?? false,
    }).save();
  }

  findActiveByEmail(email: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ email: email.toLowerCase(), isDeleted: false }).exec();
  }

  findActiveByGoogleId(googleId: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ googleId, isDeleted: false }).exec();
  }

  findActiveById(id: string): Promise<UserDocument | null> {
    return this.userModel.findOne({ _id: id, isDeleted: false }).exec();
  }

  updateById(id: string, update: UpdateQuery<UserDocument>): Promise<UserDocument | null> {
    return this.userModel.findByIdAndUpdate(id, update, { new: true, runValidators: true }).exec();
  }

  updateOne(filter: FilterQuery<UserDocument>, update: UpdateQuery<UserDocument>): Promise<void> {
    return this.userModel
      .updateOne(filter, update)
      .exec()
      .then(() => undefined);
  }

  async markDeleted(id: string): Promise<void> {
    await this.userModel
      .updateOne(
        { _id: id },
        { $set: { isDeleted: true, deletedAt: new Date(), lastActiveAt: new Date() } },
      )
      .exec();
  }
}
