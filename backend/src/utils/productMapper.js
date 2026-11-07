function parseJson(value, fallback) {
  if (typeof value !== 'string') {
    return value ?? fallback;
  }

  try {
    return JSON.parse(value);
  } catch {
    return fallback;
  }
}

function parseImages(value) {
  const parsed = parseJson(value, []);

  if (!Array.isArray(parsed)) {
    return [];
  }

  return parsed
    .filter((image) => image?.id && image?.imageUrl)
    .map((image) => ({
      id: Number(image.id),
      imageUrl: String(image.imageUrl),
      altText: image.altText ?? null,
      displayOrder: Number(image.displayOrder ?? 0),
      isPrimary:
        image.isPrimary === true ||
        image.isPrimary === 1 ||
        image.isPrimary === '1',
    }))
    .sort(
      (a, b) =>
        Number(b.isPrimary) - Number(a.isPrimary) ||
        a.displayOrder - b.displayOrder ||
        a.id - b.id,
    );
}

function parseSpecifications(value) {
  const parsed = parseJson(value, {});

  if (
    !parsed ||
    typeof parsed !== 'object' ||
    Array.isArray(parsed)
  ) {
    return {};
  }

  return parsed;
}

export function mapProduct(row) {
  const images = parseImages(row.images);

  return {
    id: Number(row.id),
    categoryId: Number(row.category_id),
    categoryName: row.category_name ?? '',
    categorySlug: row.category_slug ?? '',

    name: row.name,
    slug: row.slug,
    shortDescription: row.short_description ?? null,
    description: row.description ?? null,

    price: Number(row.price),

    comparePrice:
      row.compare_price == null
        ? null
        : Number(row.compare_price),

    stockQuantity: Number(row.stock_quantity),

    featured: Number(row.featured) === 1,
    isActive: Number(row.is_active) === 1,

    specifications: parseSpecifications(row.specifications),

    images,
    primaryImage: images[0]?.imageUrl ?? null,

    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}