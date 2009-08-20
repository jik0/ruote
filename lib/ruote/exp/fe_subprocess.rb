#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'ruote/exp/flowexpression'


module Ruote::Exp

  #
  # An expression for invoking a subprocess.
  #
  #   pdef = Ruote.process_definition do
  #     sequence do
  #       subprocess :ref => 'delivering'
  #       subprocess 'invoicing'
  #       refill_stock :if => '${v:stock_size} < 10'
  #     end
  #     define 'delivering' do
  #       # ...
  #     end
  #     define 'invoicing' do
  #       # ...
  #     end
  #     define 'refill_stock' do
  #       # ...
  #     end
  #   end
  #
  #
  # == passing attributes as variables
  #
  # The attributes of the subprocess expression are passed as variables of
  # the new subprocess instance.
  #
  #   Ruote.process_definition do
  #     subprocess 'sub0', :a => 'A', :b => 'B'
  #     define :sub0 do
  #       echo '${v:a}:${v:b}'
  #     end
  #   end
  #
  # This example (and useless) process example will output "A:B" to STDOUT.
  #
  #
  # == passing 'blocks' to subprocesses
  #
  # When the subprocess expression has children, the first of them is passed
  # to the subprocess instance as the __tree__ variable, readily available for
  # an 'apply' expression.
  #
  #   Ruote.process_definition :name => 'double review' do
  #     sequence do
  #       sub0 do
  #         review_board
  #       end
  #       sub0 do
  #         review_board
  #       end
  #     end
  #     define 'sub0' do
  #       concurrence do
  #         apply :i => 0
  #         apply :i => 1
  #         apply :i => 2
  #       end
  #     end
  #   end
  #
  # This example will send 2 x 3 concurrent workitems to the participant
  # named 'review_board' (note that it could also be the name of another
  # subprocess).
  #
  class SubprocessExpression < FlowExpression

    names :subprocess


    def apply

      ref = attribute(:ref) || attribute_text

      raise "no subprocess referred in #{tree}" unless ref

      pos, subtree = lookup_variable(ref)

      raise "no subprocess named '#{ref}' found" unless subtree.is_a?(Array)

      vars = compile_attributes
      vars.merge!('__tree__' => tree_children.first)

      pool.launch_sub(pos, subtree, self, @applied_workitem, :variables => vars)
    end
  end
end

