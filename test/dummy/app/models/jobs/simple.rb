module Jobs
  module Simple
    class GetOriginalMediaURL
      include Graphene::Tasks::Task

      def call
        yield("Janusz")
      end
    end

    class Job < Graphene::Jobs::Base
      STACK = Graphene::Stack[
        Jobs::Simple::GetOriginalMediaURL
      ]
    end
  end
end
