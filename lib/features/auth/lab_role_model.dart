/// Represents a single role within a medical laboratory.
class LabRoleInfo {
  final String title;
  final String description;
  final String icon;
  final String apiValue;

  const LabRoleInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.apiValue,
  });
}

/// All supported laboratory roles, ordered by function.
const List<LabRoleInfo> labRoles = [
  LabRoleInfo(
    title: 'Lab Technician',
    description: 'Performs daily laboratory tests and operates instruments',
    icon: '🔬',
    apiValue: 'lab_technician',
  ),
  LabRoleInfo(
    title: 'Pathologist',
    description: 'Interprets test results and provides diagnoses',
    icon: '👨‍⚕️',
    apiValue: 'pathologist',
  ),
  LabRoleInfo(
    title: 'Pharmacist',
    description: 'Manages medications and validates prescriptions',
    icon: '💊',
    apiValue: 'pharmacist',
  ),
  LabRoleInfo(
    title: 'Lab Manager',
    description: 'Oversees laboratory operations and quality standards',
    icon: '🏥',
    apiValue: 'lab_manager',
  ),
  LabRoleInfo(
    title: 'Clinical Researcher',
    description: 'Conducts clinical studies and research trials',
    icon: '🩺',
    apiValue: 'clinical_researcher',
  ),
  LabRoleInfo(
    title: 'Quality Control Officer',
    description: 'Ensures test accuracy and regulatory compliance',
    icon: '📋',
    apiValue: 'quality_control_officer',
  ),
];
