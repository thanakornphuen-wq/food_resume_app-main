import 'package:flutter_test/flutter_test.dart';
import 'package:food_resume_app/models/food_resume.dart';

void main() {
  FoodResume menu() => FoodResume(
    id: 'menu', menuName: 'Soup', category: 'อาหารไทย',
    ownerId: 'owner', imageUrl: 'https://example.com/soup.jpg',
    description: 'Recipe', ingredients: ['Water'], instructions: ['Boil'],
    likeCount: 2, likedBy: ['alice', 'bob'], createdAt: DateTime(2026),
  );

  test('New votes retain legacy likes and recipe details', () {
    final original = menu();
    final result = original.withLikes({'carol': true});
    expect(result.likeCount, 3);
    expect(result.likedBy, containsAll(['alice', 'bob', 'carol']));
    expect(result.imageUrl, original.imageUrl);
    expect(result.description, original.description);
    expect(result.ingredients, original.ingredients);
    expect(result.instructions, original.instructions);
    expect(original.likedBy, ['alice', 'bob']);
  });

  test('Users can unlike legacy votes without removing other votes', () {
    final result = menu().withLikes({'alice': false, 'carol': true});
    expect(result.likeCount, 2);
    expect(result.likedBy, ['bob', 'carol']);
  });

  test('Existing vote is not counted twice and can be liked again', () {
    expect(menu().withLikes({'alice': true}).likeCount, 2);
    final result = menu().withLikes({'alice': false}).withLikes({'alice': true});
    expect(result.likeCount, 2);
    expect(result.isLikedBy('alice'), isTrue);
  });
}
