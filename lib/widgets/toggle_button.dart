import 'package:flutter/material.dart';

class ModernToggleButton extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;

  const ModernToggleButton({
    super.key,
    required this.isLogin,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: isLogin ? 0 : 100,
            child: Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isLogin) onToggle();
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: isLogin ? Colors.blue : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isLogin) onToggle();
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: !isLogin ? Colors.green : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}