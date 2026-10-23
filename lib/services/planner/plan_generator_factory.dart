import 'plan_generator_interface.dart';
import 'rule_based_plan_generator.dart';

/// Constructs the active [PlanGeneratorInterface] used by the whole app.
class PlanGeneratorFactory {
  PlanGeneratorFactory._();

  /// THE single swap point for the plan "brain".
  ///
  /// To switch generators later (e.g. to an LLM or custom ML model), only this
  /// method changes: return `LlmPlanGenerator()` / `MlPlanGenerator()` instead
  /// of `RuleBasedPlanGenerator()`. No other file needs to know about it.
  static PlanGeneratorInterface getActivePlanGenerator() =>
      RuleBasedPlanGenerator();
}