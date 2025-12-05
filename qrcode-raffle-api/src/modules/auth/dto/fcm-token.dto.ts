import { IsNotEmpty, IsString } from 'class-validator';

export class FcmTokenDto {
  @IsString()
  @IsNotEmpty({ message: 'FCM token é obrigatório' })
  fcmToken: string;
}
