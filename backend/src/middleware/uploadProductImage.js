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
  'image/jpg',
  'image/png',
  'image/webp',
  'image/avif',
]);

const allowedExtensions = new Set([
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.avif',
]);

const extensionByMimeType = {
  'image/jpeg': '.jpg',
  'image/jpg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/avif': '.avif',
};

function getFileExtension(file) {
  const originalExtension = path
    .extname(file.originalname)
    .toLowerCase();

  return (
    extensionByMimeType[file.mimetype] ??
    originalExtension
  );
}

const storage = multer.diskStorage({
  destination(request, file, callback) {
    callback(null, uploadDirectory);
  },

  filename(request, file, callback) {
    const extension = getFileExtension(file);

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
    const extension = path
      .extname(file.originalname)
      .toLowerCase();

    const hasValidExtension =
      allowedExtensions.has(extension);

    const hasValidMimeType =
      allowedMimeTypes.has(file.mimetype);

    /*
      Một số trình duyệt gửi file Flutter Web dưới dạng
      application/octet-stream. Trong trường hợp đó, backend
      kiểm tra phần mở rộng file.
    */
    const isBrowserBinary =
      file.mimetype === 'application/octet-stream';

    if (
      !hasValidExtension ||
      (!hasValidMimeType && !isBrowserBinary)
    ) {
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