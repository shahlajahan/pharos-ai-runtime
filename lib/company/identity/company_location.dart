/// Where a Company is located. Stores only values — no address, no GPS,
/// no maps.
class CompanyLocation {
  const CompanyLocation({
    required this.country,
    required this.region,
    required this.city,
  });

  final String country;
  final String region;
  final String city;
}
