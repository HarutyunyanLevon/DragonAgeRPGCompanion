import 'package:flutter/material.dart';

/// A scrolling form column that stays readable on wide windows ([maxWidth]).
/// [padding] and [controller] are only needed by pages that float something
/// over the content or want to know where it is scrolled to.
class FormBody extends StatelessWidget {
  const FormBody({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.controller,
    this.maxWidth = 640,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final ScrollController? controller;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          controller: controller,
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Small heading above a group of fields.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Heading for a group inside a section.
class SubsectionTitle extends StatelessWidget {
  const SubsectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
