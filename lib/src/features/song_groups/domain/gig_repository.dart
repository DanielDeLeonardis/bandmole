import 'gig.dart';

abstract class GigRepository {
  Future<List<Gig>> loadGigs();
  Future<void> saveGig(Gig gig);
  Future<void> deleteGig(String gigId);
}
