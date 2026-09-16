function parseImages(value) {
  if (!value) {
    return [];
  }

  if (Array.isArray(value)) {
    return value;
  }

  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch {
      return [];
    }
  }

  return [];
}

function parseSpecifications(value) {
  if (!value) {
    return {};
  }

  if (typeof value === 'object') {
    return value;
  }

  try {
    return JSON.parse(value);
  } catch {
    return {};
  }
}

export function mapProduct(row) {
  const images = parseImages(row.images).filter(
    (image) => image?.id && image?.imageUrl,
  );

  return {
    id: row.id,
    categoryId: row.category_id,
    categoryName: row.category_name,
    categorySlug: row.category_slug,

    name: row.name,
    slug: row.slug,
    shortDescription: row.short_description,
    description: row.description,

    price: Number(row.price),
    comparePrice:
      row.compare_price === null
        ? null
        : Number(row.compare_price),

    stockQuantity: Number(row.stock_quantity),
    featured: Boolean(row.featured),
    isActive: Boolean(row.is_active),

    specifications: parseSpecifications(
      row.specifications,
    ),

    images,
    primaryImage:
      images.find((image) => image.isPrimary)?.imageUrl ??
      images[0]?.imageUrl ??
      null,

    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}