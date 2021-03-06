require "spec_helper"

module VCAP::CloudController
  describe VCAP::CloudController::SshController, type: :controller do
    describe "GET /v2/apps/:id/instances/ssh" do
      before :each do
        @app = AppFactory.make(:package_hash => "abc", :package_state => "STAGED")
        @user =  make_user_for_space(@app.space)
        @developer = make_developer_for_space(@app.space)
        @auditor = make_auditor_for_space(@app.space)
      end

      context "as a developer" do
        it "should return 400 when there is an error finding the instances" do
          instance_id = 5

          @app.state = "STARTED"
          @app.save

          get("/v2/apps/#{@app.guid}/instances/#{instance_id}/ssh",
              {},
              headers_for(@developer))
          
          last_response.status.should == 400
        end

        it "should return the ssh details" do
          @app.state = "STARTED"
          @app.instances = 1
          @app.save

          @app.refresh

          response = { 
            "ip" => VCAP.local_ip,
            "sshkey" => "fakekey",
            "user" => "vcap",
            "port" => 1234
          }
          
          expected = { 
            "ip" => VCAP.local_ip,
            "sshkey" => "fakekey",
            "user" => "vcap",
            "port" => 1234
          }

          DeaClient.should_receive(:ssh_instance).with(@app, 0).
            and_return(response)

          get("v2/apps/#{@app.guid}/instances/0/ssh",
              {},
              headers_for(@developer))

          last_response.status.should == 200
          Yajl::Parser.parse(last_response.body).should == expected
        end
      end

      context "as a user" do
        it "should return 403" do
          get("v2/apps/#{@app.guid}/instances/0/ssh",
              {},
              headers_for(@user))

              last_response.status.should == 403
        end
      end
      
      context "as a auditor" do

        it "should return the ssh details" do
          @app.state = "STARTED"
          @app.instances = 1
          @app.save

          @app.refresh

          response = { 
            "ip" => VCAP.local_ip,
            "sshkey" => "fakekey",
            "user" => "vcap",
            "port" => 1234
          }
          
          expected = { 
            "ip" => VCAP.local_ip,
            "sshkey" => "fakekey",
            "user" => "vcap",
            "port" => 1234
          }

          DeaClient.should_receive(:ssh_instance).with(@app, 0).
            and_return(response)

          get("v2/apps/#{@app.guid}/instances/0/ssh",
              {},
              headers_for(@auditor))

          last_response.status.should == 200
          Yajl::Parser.parse(last_response.body).should == expected
        end
      end
    end
  end
end
