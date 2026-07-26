============================================================
Fork parenthesized expressions with upstream declaration/access rules
============================================================
Перем Флаг Экспорт, Значение;
Результат = Обработать((Флаг И Значение.По));
---

(source_file
  (var_definition
    (VAR_KEYWORD)
    variable: (variable_spec
      name: (identifier)
      export: (EXPORT_KEYWORD))
    variable: (variable_spec
      name: (identifier)))
  (assignment_statement
    left: (identifier)
    right: (expression
      (method_call
        name: (identifier)
        arguments: (arguments
          (expression
            (parenthesized_expression
              (expression
                (binary_expression
                  left: (expression
                    (identifier))
                  operator: (operator)
                  right: (expression
                      (property_access
                        (access
                          (identifier))
                      (property
                        (TO_KEYWORD)))))))))))))
