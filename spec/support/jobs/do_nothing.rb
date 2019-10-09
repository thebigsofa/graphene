# frozen_string_literal: true

module Support
  module Jobs
    class DoNothing < Graphene::Jobs::Base
      def process
        # Do nothing
      end
    end

    module QA
      class IntegrityFilter < Support::Jobs::DoNothing; end;
      class DuplicateFilter < Support::Jobs::DoNothing; end;
      class DurationFilter < Support::Jobs::DoNothing; end;
      class AdultContentFilter < Support::Jobs::DoNothing; end;
    end

    module Transform
      class Zencoder < Support::Jobs::DoNothing; end;
    end

    module Process
      class ExtractFrames < Support::Jobs::DoNothing; end;
      class ExtractMetadata < Support::Jobs::DoNothing; end;
      class AudioActivityDetection < Support::Jobs::DoNothing; end;
      class VideoActivityDetection < Support::Jobs::DoNothing; end;
      class GenerateThumbnails < Support::Jobs::DoNothing; end;
    end

    module Analysis
      class BehaviouralRecognition < Support::Jobs::DoNothing; end;
      class PeopleDetection < Support::Jobs::DoNothing; end;
    end
  end
end
