module MigrationHelpers
  def foreign_key(from_table, from_column, to_table, constraint_num)
#   constraint_name = "fk_#{from_table}_#{from_column}" 
    constraint_name = "fk_orc_#{constraint_num}"

    execute %{alter table #{from_table}
              add constraint #{constraint_name}
              foreign key (#{from_column})
              references #{to_table}(id)}
  end
end
