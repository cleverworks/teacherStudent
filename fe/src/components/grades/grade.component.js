import React, { Component } from "react";
import GradeDataService from "../../services/grade.service";
import { withRouter } from '../../common/with-router';

class Grade extends Component {
  constructor(props) {
    super(props);
    this.onChangeTitle = this.onChangeTitle.bind(this);
    this.onChangeDescription = this.onChangeDescription.bind(this);
    this.getGrade = this.getGrade.bind(this);
    this.updatePublished = this.updatePublished.bind(this);
    this.updateGrade = this.updateGrade.bind(this);
    this.deleteGrade = this.deleteGrade.bind(this);

    this.state = {
      currentGrade: {
        id: null,
        title: "",
        descr: ""
      },
      message: ""
    };
  }

  componentDidMount() {
    this.getGrade(this.props.router.params.id);
  }

  onChangeTitle(e) {
    const title = e.target.value;

    this.setState(function(prevState) {
      return {
        currentGrade: {
          ...prevState.currentGrade,
          title: title
        }
      };
    });
  }

  onChangeDescription(e) {
    const descr = e.target.value;
    
    this.setState(prevState => ({
      currentGrade: {
        ...prevState.currentGrade,
        descr: descr
      }
    }));
  }

  getGrade(id) {
    GradeDataService.get(id)
      .then(response => {
        this.setState({
          currentGrade: response.data
        });
        console.log(response.data);
      })
      .catch(e => {
        console.log(e);
      });
  }

  updatePublished(status) {
    var data = {
      id: this.state.currentGrade._id.$oid,
      title: this.state.currentGrade.title,
      descr: this.state.currentGrade.descr,
      published: status
    };

    GradeDataService.update(this.state.currentGrade._id.$oid, data)
      .then(response => {
        this.setState(prevState => ({
          currentGrade: {
            ...prevState.currentGrade,
            published: status
          }
        }));
        console.log(response.data);
      })
      .catch(e => {
        console.log(e);
      });
  }

  updateGrade() {
    GradeDataService.update(
      this.state.currentGrade._id.$oid,
      this.state.currentGrade
    )
      .then(response => {
        console.log(response.data);
        this.setState({
          message: "The grade was updated successfully!"
        });
      })
      .catch(e => {
        console.log(e);
      });
  }

  deleteGrade() {    
    GradeDataService.delete(this.state.currentGrade._id.$oid)
      .then(response => {
        console.log(response.data);
        this.props.router.navigate('/grades');
      })
      .catch(e => {
        console.log(e);
      });
  }

  render() {
    const { currentGrade } = this.state;

    return (
      <div>
        {currentGrade ? (
          <div className="edit-form">
            <h4>Grade</h4>
            <form>
              <div className="form-group">
                <label htmlFor="title">Title</label>
                <input
                  type="text"
                  className="form-control"
                  id="title"
                  value={currentGrade.title}
                  onChange={this.onChangeTitle}
                />
              </div>
              <div className="form-group">
                <label htmlFor="descr">Description</label>
                <input
                  type="text"
                  className="form-control"
                  id="descr"
                  value={currentGrade.descr}
                  onChange={this.onChangeDescription}
                />
              </div>
            </form>

            {currentGrade.published ? (
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
              onClick={this.deleteGrade}
            >
              Delete
            </button>

            <button
              type="submit"
              className="badge badge-success"
              onClick={this.updateGrade}
            >
              Update
            </button>
            <p>{this.state.message}</p>
          </div>
        ) : (
          <div>
            <br />
            <p>Please click on a Grade...</p>
          </div>
        )}
      </div>
    );
  }
}

export default withRouter(Grade);