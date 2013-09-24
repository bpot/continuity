require 'spec_helper'
require 'continuity/zk_backend'

describe Continuity::ZkBackend do
  before do
    @zk = Continuity::ZkBackend.new("localhost:2181", :frequency => 1, :loop => false)
  end

  describe "#each_epoch" do
    before(:each) do
      @zk.candidate.stub(:vote!)
      @zk.zk.stub(:get).and_return(["0",nil])
      @zk.zk.stub(:create)
      @zk.zk.stub(:set)
    end

    context "with successful election" do
      before(:each) do
        @zk.candidate.stub(:on_winning_election) do |&block|
          block.call
        end
      end

      it "conducts an election" do
        @zk.candidate.should_receive :vote!
        @zk.each_epoch {|range| range}
      end

      it "calls passed block with epoch if time has passed" do
        callable = Proc.new {|range| range}
        callable.should_receive :call
        @zk.each_epoch(&callable)
      end

      it "doesn't call passed block if no time has passed" do
        callable = Proc.new {|range| range}
        callable.should_receive :call
        @zk.each_epoch(&callable)
      end
    end

    context "with unsuccessful election" do
      before(:each) do
        @zk.candidate.stub(:on_winning_election)
      end

      it "doesn't call passed block" do
        callable = Proc.new {|range| range}
        callable.should_not_receive :call
        @zk.each_epoch(&callable)
      end
    end
  end
end

