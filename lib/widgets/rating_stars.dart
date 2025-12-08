import 'package:flutter/material.dart';

typedef OnRatingChanged = void Function(int rating);

class RatingStars extends StatefulWidget {
  final int initialRating;
  final OnRatingChanged? onChanged;
  final double iconSize;

  const RatingStars({
    super.key,
    this.initialRating = 5,
    this.onChanged,
    this.iconSize = 32,
  });

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.clamp(1, 5);
  }

  void _setRating(int r) {
    setState(() => _rating = r);
    widget.onChanged?.call(_rating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final index = i + 1;
        final filled = index <= _rating;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tight(Size(widget.iconSize + 8, widget.iconSize + 8)),
          icon: Icon(
            Icons.star,
            size: widget.iconSize,
            color: filled ? Colors.amber : Colors.grey.shade400,
          ),
          onPressed: () => _setRating(index),
        );
      }),
    );
  }
}
