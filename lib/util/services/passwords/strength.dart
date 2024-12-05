import 'package:flutter/material.dart';
import 'package:random_password_generator/random_password_generator.dart';

///Strength Handler
class StrengthHandler {
  ///Random Password Generator
  static final _randomPasswordGenerator = RandomPasswordGenerator();

  ///Generate Strong Password
  static String generateStrongPassword({
    required int length,
    required bool numbers,
    required bool upperCase,
    required bool symbols,
  }) {
    //Password
    final password = _randomPasswordGenerator.randomPassword(
      passwordLength: length.toDouble(),
      numbers: numbers,
      uppercase: upperCase,
      specialChar: symbols,
    );

    //Return Password
    return password;
  }

  ///Check if a Given `password` is Strong
  static double isStrong(String password) {
    //Strength Score
    double score = _randomPasswordGenerator.checkPassword(password: password);

    //Return Score
    return score;
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  ///Password Strength
  final double strength;

  ///Indicator Height
  final double height;

  ///Indicator Width
  final double width;

  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
    this.height = 8.0,
    this.width = double.infinity,
  });

  ///Color from Strength
  Color _getColorForStrength() {
    if (strength <= 0.3) {
      return Colors.red;
    } else if (strength <= 0.6) {
      return Colors.orange;
    } else if (strength <= 0.8) {
      return Colors.yellow.shade700;
    }
    return Colors.green;
  }

  ///Text from Strength
  String _getTextFromStrength() {
    if (strength <= 0.3) {
      return "Weak";
    } else if (strength <= 0.6) {
      return "Medium";
    }
    return "Strong";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //Strength Indicator
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: strength.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: _getColorForStrength(),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),

        //Spacing
        const SizedBox(height: 10.0),

        //Strength Percentage
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _getTextFromStrength(),
            style: TextStyle(color: _getColorForStrength()),
          ),
        ),
      ],
    );
  }
}
