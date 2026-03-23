# frozen_string_literal: true

require "active_support/callbacks"
require "active_support/core_ext/module/attribute_accessors"

module ActiveJob
  # = Active Job \Callbacks
  #
  # Active Job provides hooks during the life cycle of a job. Callbacks allow you
  # to trigger logic during this cycle. Available callbacks are:
  #
  # * <tt>before_enqueue</tt>
  # * <tt>around_enqueue</tt>
  # * <tt>after_enqueue</tt>
  # * <tt>before_perform</tt>
  # * <tt>around_perform</tt>
  # * <tt>after_perform</tt>

  class << self
    # Defines a callback that will get called right before
    # +perform_all_later+ enqueues the jobs. The callback receives
    # the array of jobs as an argument. Jobs can be rejected by
    # setting +successfully_enqueued = false+ on them, which
    # prevents them from being enqueued.
    #
    #   ActiveJob.before_perform_all_later do |jobs|
    #     jobs.each { |job| job.successfully_enqueued = false if job.arguments.first.nil? }
    #   end
    def before_perform_all_later(*filters, &blk)
      ActiveJob::Callbacks.singleton_class.set_callback(:perform_all_later, :before, *filters, &blk)
    end

    # Defines a callback that will get called around
    # +perform_all_later+'s enqueuing of the jobs.
    #
    #   ActiveJob.around_perform_all_later do |jobs, block|
    #     log "Enqueuing #{jobs.size} jobs"
    #     block.call
    #     log "Done enqueuing"
    #   end
    def around_perform_all_later(*filters, &blk)
      ActiveJob::Callbacks.singleton_class.set_callback(:perform_all_later, :around, *filters, &blk)
    end

    # Defines a callback that will get called right after
    # +perform_all_later+ has enqueued the jobs.
    #
    #   ActiveJob.after_perform_all_later do |jobs|
    #     log "Enqueued #{jobs.count(&:successfully_enqueued?)} jobs"
    #   end
    def after_perform_all_later(*filters, &blk)
      ActiveJob::Callbacks.singleton_class.set_callback(:perform_all_later, :after, *filters, &blk)
    end
  end

  module Callbacks
    extend  ActiveSupport::Concern
    include ActiveSupport::Callbacks

    class << self
      include ActiveSupport::Callbacks
      define_callbacks :execute
      define_callbacks :perform_all_later
    end

    included do
      define_callbacks :perform, skip_after_callbacks_if_terminated: true
      define_callbacks :enqueue, skip_after_callbacks_if_terminated: true
    end

    # These methods will be included into any Active Job object, adding
    # callbacks for +perform+ and +enqueue+ methods.
    module ClassMethods
      # Defines a callback that will get called right before the
      # job's perform method is executed.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     before_perform do |job|
      #       UserMailer.notify_video_started_processing(job.arguments.first)
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      def before_perform(*filters, &blk)
        set_callback(:perform, :before, *filters, &blk)
      end

      # Defines a callback that will get called right after the
      # job's perform method has finished.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     after_perform do |job|
      #       UserMailer.notify_video_processed(job.arguments.first)
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      def after_perform(*filters, &blk)
        set_callback(:perform, :after, *filters, &blk)
      end

      # Defines a callback that will get called around the job's perform method.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     around_perform do |job, block|
      #       UserMailer.notify_video_started_processing(job.arguments.first)
      #       block.call
      #       UserMailer.notify_video_processed(job.arguments.first)
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      # You can access the return value of the job only if the execution wasn't halted.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     around_perform do |job, block|
      #       value = block.call
      #       puts value # => "Hello World!"
      #     end
      #
      #     def perform
      #       "Hello World!"
      #     end
      #   end
      #
      def around_perform(*filters, &blk)
        set_callback(:perform, :around, *filters, &blk)
      end

      # Defines a callback that will get called right before the
      # job is enqueued.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     before_enqueue do |job|
      #       $statsd.increment "enqueue-video-job.try"
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      def before_enqueue(*filters, &blk)
        set_callback(:enqueue, :before, *filters, &blk)
      end

      # Defines a callback that will get called right after the
      # job is enqueued.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     after_enqueue do |job|
      #       result = job.successfully_enqueued? ? "success" : "failure"
      #       $statsd.increment "enqueue-video-job.#{result}"
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      def after_enqueue(*filters, &blk)
        set_callback(:enqueue, :after, *filters, &blk)
      end

      # Defines a callback that will get called around the enqueuing
      # of the job.
      #
      #   class VideoProcessJob < ActiveJob::Base
      #     queue_as :default
      #
      #     around_enqueue do |job, block|
      #       $statsd.time "video-job.process" do
      #         block.call
      #       end
      #     end
      #
      #     def perform(video_id)
      #       Video.find(video_id).process
      #     end
      #   end
      #
      def around_enqueue(*filters, &blk)
        set_callback(:enqueue, :around, *filters, &blk)
      end
    end
  end
end
