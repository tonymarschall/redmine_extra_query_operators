module ExtraQueryOperators
  module Patches
    module QueryModelPatch
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method_chain :sql_for_field, :date_range
          #alias_method_chain :add_filter, :hash

          class << self
            alias_method_chain :operators_by_filter_type, :date_range
            alias_method_chain :operators, :date_range
          end
        end
      end
      
      module ClassMethods
        def operators_with_date_range
          o=operators_without_date_range
          if o["t>"].blank?
            o["t>"]=:label_eqo_after_date
            o["t<"]=:label_eqo_before_date
            o["t><"]=:label_eqo_between_date
            o["tm="]=:label_eqo_month_offset
            o["tw="]=:label_eqo_week_offset
            o["=r"]=:label_eqo_regexp
          end
          o
        end

        def operators_by_filter_type_with_date_range
          o=operators_by_filter_type_without_date_range
          unless o[:date].include?("t>")
            o[:date] = ["t><","t>","t<"] + o[:date] + ["tm=", "tw="]
            o[:date_past] = ["t><","t>","t<"] + o[:date_past] + ["tm=", "tw="]
            o[:string] << "=r"
            o[:text] << "=r"
          end
          o
        end
      end
      
      module InstanceMethods

        def sql_for_field_with_date_range(field, operator, value, db_table, db_field, is_custom_filter=false)
          sql=case operator
            when "t>"
                ("#{db_table}.#{db_field} > '%s'" % [connection.quoted_date((( Date.parse(value.first) rescue Date.today )).to_time.end_of_day)])
            when "t<"
                ("#{db_table}.#{db_field} < '%s'" % [connection.quoted_date(( Date.parse(value.first) rescue Date.today ).to_time.at_beginning_of_day)])
            when "t><"
                ("#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(( Date.parse(value[0]) rescue Date.today ).to_time.at_beginning_of_day), connection.quoted_date(( Date.parse(value[1]) rescue Date.today ).to_time.end_of_day)])
            when "tm="
              from=Time.now.at_beginning_of_month.months_ago(value.first.to_i*-1)
              to=from.at_end_of_month
              ("#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(from), connection.quoted_date(to)])
            when "tw="
              from=Time.now.at_beginning_of_week+(value.first.to_i).week
              to=Time.now.at_end_of_week+(value.first.to_i).week
              ("#{db_table}.#{db_field} BETWEEN '%s' AND '%s'" % [connection.quoted_date(from), connection.quoted_date(to)])
            when "=r"
              ("#{db_table}.#{db_field} RLIKE '#{connection.quote_string(value.first.to_s)}'")
            else
              sql_for_field_without_date_range(field, operator, value, db_table, db_field, is_custom_filter)
          end
          sql
        end

        def add_filter_with_hash(field, operator, values)
          v=values
          if values && values.is_a?(Hash)
            values_array=values.sort { |a,b| a[0].to_i <=> b[0].to_i}
            v=values_array.inject([]) { |a,value| a << value[1]; a }
            # patch to workaround blank check in query.validate
            v[0]='0' if v.first=='' && (v.detect {|value| value != '' }) != nil
          end
          add_filter_without_hash(field,operator,v)
        end

      end
    end

  end
end
