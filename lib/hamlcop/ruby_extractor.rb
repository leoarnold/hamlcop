# frozen_string_literal: true

require 'hamli'
require 'templatecop'

module Hamlcop
  # Extract Ruby codes from Haml source.
  class RubyExtractor
    class << self
      # @param [String, nil] file_path
      # @param [String] source
      def call(
        file_path:,
        source:
      )
        new(
          file_path: file_path,
          source: source
        ).call
      end
    end

    # @param [String, nil] file_path
    # @param [String] source
    def initialize(file_path:, source:)
      @file_path = file_path
      @source = source
    end

    # @return [Array<Hash>]
    def call
      ranges.map do |(begin_, end_)|
        clipped = ::Templatecop::RubyClipper.new(@source[begin_...end_]).call
        {
          code: clipped[:code],
          offset: begin_ + clipped[:offset]
        }
      end
    end

    private

    # @return [Array] Haml AST, represented in S-expression.
    def ast
      ::Hamli::Filters::Interpolation.new.call(
        ::Hamli::Parser.new(file: @file_path).call(@source)
      )
    end

    # @return [Array<Array<Integer>>]
    def ranges
      result = []
      traverse(ast) do |begin_, end_|
        result << [begin_, end_]
      end
      result
    end

    def traverse(node, &block)
      return unless node.instance_of?(::Array)

      if node[0] == :hamli && node[1] == :position
        block.call(node[2], node[3])
      else
        node.each do |element|
          traverse(element, &block)
        end
      end
    end
  end
end
