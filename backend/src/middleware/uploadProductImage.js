import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

import multer from 'multer';

import { env } from '../config/env.js';
import { HttpError } from '../utils/httpError.js';

const uploadDirectory = path.resolve(
  process.cwd(),
  env.uploadDirectory,
);

fs.mkdirSync(uploadDirectory, {
  recursive: true,
});

const allowedMimeTypes = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/avif',
]);

const storage = multer.diskStorage({
  destination(request, file, callback) {
    callback(null, uploadDirectory);
  },

  filename(request, file, callback) {
    const extensionByMimeType = {
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/webp': '.webp',
      'image/avif': '.avif',
    };

    const extension =
      extensionByMimeType[file.mimetype] ??
      path.extname(file.originalname).toLowerCase();

    callback(
      null,
      `${Date.now()}-${crypto.randomUUID()}${extension}`,
    );
  },
});

export const uploadProductImages = multer({
  storage,

  limits: {
    fileSize: env.maxImageSizeMb * 1024 * 1024,
    files: 8,
  },

  fileFilter(request, file, callback) {
    if (!allowedMimeTypes.has(file.mimetype)) {
      callback(
        new HttpError(
          400,
          'Only JPG, PNG, WebP and AVIF images are allowed.',
        ),
      );
      return;
    }

    callback(null, true);
  },
}).array('images', 8);