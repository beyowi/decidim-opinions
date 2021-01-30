# frozen_string_literal: true

module Decidim
  module Opinions
    class OpinionInputFilter < Decidim::Core::BaseInputFilter
      include Decidim::Core::HasPublishableInputFilter

      graphql_name "OpinionFilter"
      description "A type used for filtering opinions inside a participatory space.

A typical query would look like:

```
  {
    participatoryProcesses {
      components {
        ...on Opinions {
          opinions(filter:{ publishedBefore: \"2020-01-01\" }) {
            id
          }
        }
      }
    }
  }
```
"
    end
  end
end
