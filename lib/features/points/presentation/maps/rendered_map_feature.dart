sealed class RenderedMapFeature {
  const RenderedMapFeature();

  factory RenderedMapFeature.fromJson(Object? json) {
    return switch (json) {
      {'properties': {'point_count': num _, 'cluster_id': num id}} =>
        RenderedCluster(id.toInt()),
      {'properties': {'id': num id}} => RenderedPoint(id.toInt()),
      _ => const UnsupportedMapFeature(),
    };
  }
}

class RenderedCluster extends RenderedMapFeature {
  const RenderedCluster(this.id);

  final int id;
}

class RenderedPoint extends RenderedMapFeature {
  const RenderedPoint(this.id);

  final int id;
}

class UnsupportedMapFeature extends RenderedMapFeature {
  const UnsupportedMapFeature();
}
