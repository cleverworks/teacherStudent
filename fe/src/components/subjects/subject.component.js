import React, { Component } from "react";
import SubjectDataService from "../../services/subject.service";
import { withRouter } from '../../common/with-router';

class Subject extends Component {
  constructor(props) {
    super(props);
    this.onChangeTitle = this.onChangeTitle.bind(this);
    this.onChangeDescription = this.onChangeDescription.bind(this);
    this.getSubject = this.getSubject.bind(this);
    this.updatePublished = this.updatePublished.bind(this);
    this.updateSubject = this.updateSubject.bind(this);
    this.deleteSubject = this.deleteSubject.bind(this);

    this.state = {
      currentSubject: {
        id: null,
        title: "",
        descr: "",
        published: false
      },
      message: ""
    };
  }

  componentDidMount() {
    this.getSubject(this.props.router.params.id);
  }

  onChangeTitle(e) {
    const title = e.target.value;

    this.setState(function(prevState) {
      return {
        currentSubject: {
          ...prevState.currentSubject,
          title: title
        }
      };
    });
  }

  onChangeDescription(e) {
    const descr = e.target.value;
    
    this.setState(prevState => ({
      currentSubject: {
        ...prevState.currentSubject,
        descr: descr
      }
    }));
  }

  getSubject(id) {
    SubjectDataService.get(id)
      .then(response => {
        this.setState({
          currentSubject: response.data
        });
        console.log(response.data);
      })
      .catch(e => {
        console.log(e);
      });
  }

  updatePublished(status) {
    var data = {
      id: this.state.currentSubject._id.$oid,
      title: this.state.currentSubject.title,
      descr: this.state.currentSubject.descr,
      published: status
    };

    SubjectDataService.update(this.state.currentSubject._id.$oid, data)
      .then(response => {
        this.setState(prevState => ({
          currentSubject: {
            ...prevState.currentSubject,
            published: status
          }
        }));
        console.log(response.data);
      })
      .catch(e => {
        console.log(e);
      });
  }

  updateSubject() {
    SubjectDataService.update(
      this.state.currentSubject._id.$oid,
      this.state.currentSubject
    )
      .then(response => {
        console.log(response.data);
        this.setState({
          message: "The subject was updated successfully!"
        });
      })
      .catch(e => {
        console.log(e);
      });
  }

  deleteSubject() {    
    SubjectDataService.delete(this.state.currentSubject._id.$oid)
      .then(response => {
        console.log(response.data);
        this.props.router.navigate('/subjects');
      })
      .catch(e => {
        console.log(e);
      });
  }

  render() {
    const { currentSubject } = this.state;

    return (
      <div>
        {currentSubject ? (
          <div className="edit-form">
            <h4>Subject</h4>
            <form>
              <div className="form-group">
                <label htmlFor="title">Title</label>
                <input
                  type="text"
                  className="form-control"
                  id="title"
                  value={currentSubject.title}
                  onChange={this.onChangeTitle}
                />
              </div>
              <div className="form-group">
                <label htmlFor="descr">Description</label>
                <input
                  type="text"
                  className="form-control"
                  id="descr"
                  value={currentSubject.descr}
                  onChange={this.onChangeDescription}
                />
              </div>
            </form>

            {currentSubject.published ? (
              <button
                className="badge badge-primary mr-2"
                onClick={() => this.updatePublished(false)}
              >
                UnPublish
              </button>
            ) : (
              <button
                className="badge badge-primary mr-2"
                onClick={() => this.updatePublished(true)}
              >
                Publish
              </button>
            )}

            <button
              className="badge badge-danger mr-2"
              onClick={this.deleteSubject}
            >
              Delete
            </button>

            <button
              type="submit"
              className="badge badge-success"
              onClick={this.updateSubject}
            >
              Update
            </button>
            <p>{this.state.message}</p>
          </div>
        ) : (
          <div>
            <br />
            <p>Please click on a Subject...</p>
          </div>
        )}
      </div>
    );
  }
}

export default withRouter(Subject);