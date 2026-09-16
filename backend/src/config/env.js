import dotenv from 'dotenv';

dotenv.config();

const requiredVariables = [
  'DB_HOST',
  'DB_USER',
  'DB_NAME',
  'JWT_SECRET',
];

for (const variable of requiredVariables) {
  if (!process.env[variable]) {
    throw new Error(`Missing environment variable: ${variable}`);
  }
}

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 8080),
  clientUrl: process.env.CLIENT_URL ?? 'http://localhost:3000',

  database: {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT ?? 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD ?? '',
    name: process.env.DB_NAME,
  },

  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',

  uploadDirectory:
      process.env.UPLOAD_DIRECTORY ?? 'uploads/products',
  maxImageSizeMb:
      Number(process.env.MAX_IMAGE_SIZE_MB ?? 5),
};