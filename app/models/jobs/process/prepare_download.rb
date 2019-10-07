# frozen_string_literal: true

module Jobs
  module Process
    class PrepareDownload < Jobs::Base
      STACK = Stack[
        Tasks::Helpers::WithSources,
        Tasks::Helpers::DownloadSource,
        Tasks::FFMPEG::NormalizeAudio,
        Tasks::FFMPEG::TransformFile,
        Tasks::Helpers::CollectFiles
      ]

      POST_STACK = Stack[
        Tasks::Helpers::SortSources,
        Tasks::Helpers::PrepareOutputs,
        Tasks::Helpers::WithCallback,
        Tasks::UPLOAD_FILES
      ]

      # rubocop:disable Metrics/AbcSize
      def process
        process_tasks(stack) do |response|
          @dir = response
        end

        pipeline.params[group]["directory"] = @dir

        process_tasks(POST_STACK) do |response|
          yield(response) if block_given?
        end

        complete! unless pipeline.jobs.any?(&:cancelled?)
      ensure
        FileUtils.rm_r(@dir) if File.exist?(@dir.to_s)
      end
      # rubocop:enable Metrics/AbcSize

      def queue
        :pipeline_gpu
      end
    end
  end
end
