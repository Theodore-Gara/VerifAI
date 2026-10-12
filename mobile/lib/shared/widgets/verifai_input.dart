import 'package:flutter/material.dart';
import 'package:verifai/core/theme/app_colors.dart';
import 'package:verifai/core/theme/app_radius.dart';
import 'package:verifai/core/theme/app_spacing.dart';
import 'package:verifai/core/theme/app_typography.dart';

enum VerifAIInputType {
  email,
  password,
  text,
  name,
}

class VerifAIInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final VerifAIInputType type;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;

  const VerifAIInput({
    super.key,
    this.label,
    this.hint,
    this.type = VerifAIInputType.text,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  State<VerifAIInput> createState() => _VerifAIInputState();
}

class _VerifAIInputState extends State<VerifAIInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _obscureText = true;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.type == VerifAIInputType.password;
  }

  void _onFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          obscureText: _obscureText,
          maxLines: widget.maxLines,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          validator: widget.validator,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: AppTypography.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            suffixIcon: widget.type == VerifAIInputType.password
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  )
                : null,
            filled: true,
            fillColor:
                widget.enabled ? AppColors.surface : AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(
                color: _hasFocus ? AppColors.primaryNavy : AppColors.border,
                width: _hasFocus ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide:
                  const BorderSide(color: AppColors.primaryNavy, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            errorStyle: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
