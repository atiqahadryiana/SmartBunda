import 'package:flutter/material.dart';

class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _built;

  @override
  void initState() {
    super.initState();
    _built = List<bool>.generate(
      widget.children.length,
      (i) => i == widget.index,
    );
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != _built.length) {
      _built = List<bool>.generate(
        widget.children.length,
        (i) => i == widget.index,
      );
      return;
    }
    if (widget.index >= 0 && widget.index < _built.length) {
      _built[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < widget.children.length; i++) {
      children.add(_built[i] ? widget.children[i] : const SizedBox.shrink());
    }
    return IndexedStack(
      index: widget.index,
      children: children,
    );
  }
}
